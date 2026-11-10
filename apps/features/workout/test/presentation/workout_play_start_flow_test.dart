import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final class _Store implements ActiveWorkoutDraftStore {
  ActiveWorkoutDraft? saved;

  @override
  Future<ActiveWorkoutDraft?> load() async => saved;

  @override
  Future<void> save(ActiveWorkoutDraft draft) async => saved = draft;

  @override
  Future<void> delete() async => saved = null;
}

String _id(int n) =>
    '00000000-0000-4000-8000-${n.toRadixString(16).padLeft(12, '0')}';

ActiveWorkoutDraft _draft() => ActiveWorkoutDraft(
      id: _id(1),
      ownerId: _id(2),
      saveRequestId: _id(3),
      time: WorkoutTime.start(startedAtUtc: DateTime.utc(2026, 11, 10, 8)),
    );

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData.dark().copyWith(extensions: const [TioColors.dark]),
      home: home,
    );

void main() {
  testWidgets('Play with no in-progress workout opens a new start',
      (tester) async {
    var openedResume = false;
    var openedNew = false;
    final store = _Store();

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await runWorkoutPlayStart(
                  context: context,
                  draftStore: store,
                  openActive: ({required bool resumeExisting}) {
                    if (resumeExisting) {
                      openedResume = true;
                    } else {
                      openedNew = true;
                    }
                  },
                );
              },
              child: const Text('Play'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(openedNew, isTrue);
    expect(openedResume, isFalse);
    expect(find.text('You have a workout in progress'), findsNothing);
  });

  testWidgets('Play with stored draft shows card; Resume opens existing',
      (tester) async {
    var openedResume = false;
    var openedNew = false;
    final store = _Store()..saved = _draft();

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await runWorkoutPlayStart(
                  context: context,
                  draftStore: store,
                  openActive: ({required bool resumeExisting}) {
                    if (resumeExisting) {
                      openedResume = true;
                    } else {
                      openedNew = true;
                    }
                  },
                );
              },
              child: const Text('Play'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    expect(find.text('You have a workout in progress'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('workout-in-progress-resume')));
    await tester.pumpAndSettle();
    expect(openedResume, isTrue);
    expect(openedNew, isFalse);
    expect(store.saved, isNotNull);
  });

  testWidgets('Start new workout deletes the old draft then opens fresh',
      (tester) async {
    var openedResume = false;
    var openedNew = false;
    final store = _Store()..saved = _draft();
    final draftController = ActiveWorkoutDraftController(
      store: store,
      ownerId: _id(2),
      newUuid: () => _id(40),
    );

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await runWorkoutPlayStart(
                  context: context,
                  draftController: draftController,
                  draftStore: store,
                  openActive: ({required bool resumeExisting}) {
                    if (resumeExisting) {
                      openedResume = true;
                    } else {
                      openedNew = true;
                    }
                  },
                );
              },
              child: const Text('Play'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('workout-in-progress-start-new')));
    await tester.pumpAndSettle();

    expect(openedNew, isTrue);
    expect(openedResume, isFalse);
    expect(store.saved, isNull);
    expect(draftController.draft, isNull);
  });

  testWidgets('Cancel leaves the stored draft untouched', (tester) async {
    var opened = false;
    final store = _Store()..saved = _draft();

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await runWorkoutPlayStart(
                  context: context,
                  draftStore: store,
                  openActive: ({required bool resumeExisting}) {
                    opened = true;
                  },
                );
              },
              child: const Text('Play'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-in-progress-cancel')));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
    expect(store.saved, isNotNull);
  });

  testWidgets(
      'Play fails closed when durable draft load is unreadable',
      (tester) async {
    var opened = false;
    final store = _FailLoadStore();

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await runWorkoutPlayStart(
                  context: context,
                  draftStore: store,
                  openActive: ({required bool resumeExisting}) {
                    opened = true;
                  },
                );
              },
              child: const Text('Play'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();

    expect(opened, isFalse);
    expect(find.text('You have a workout in progress'), findsNothing);
  });

  testWidgets(
      'Start new fails closed when durable delete fails and memory draft remains',
      (tester) async {
    var openedNew = false;
    final store = _FailDeleteStore()..saved = _draft();
    final draftController = ActiveWorkoutDraftController(
      store: store,
      ownerId: _id(2),
      newUuid: () => _id(41),
    );
    expect(await draftController.restoreExisting(), isTrue);

    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await runWorkoutPlayStart(
                  context: context,
                  draftController: draftController,
                  draftStore: store,
                  openActive: ({required bool resumeExisting}) {
                    if (!resumeExisting) openedNew = true;
                  },
                );
              },
              child: const Text('Play'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Play'));
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('workout-in-progress-start-new')));
    await tester.pumpAndSettle();

    expect(openedNew, isFalse);
    expect(draftController.draft, isNotNull);
    draftController.dispose();
  });
}

final class _FailDeleteStore implements ActiveWorkoutDraftStore {
  ActiveWorkoutDraft? saved;

  @override
  Future<ActiveWorkoutDraft?> load() async => saved;

  @override
  Future<void> save(ActiveWorkoutDraft draft) async => saved = draft;

  @override
  Future<void> delete() async => throw StateError('delete failed');
}

final class _FailLoadStore implements ActiveWorkoutDraftStore {
  @override
  Future<ActiveWorkoutDraft?> load() async =>
      throw StateError('secure draft unavailable');

  @override
  Future<void> save(ActiveWorkoutDraft draft) async {}

  @override
  Future<void> delete() async {}
}
