import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final _sessionId = WorkoutSessionId('22222222-2222-4222-a222-222222222222');
final _started = DateTime.utc(2026, 11, 11, 20);

class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog(const []);
}

class _Repository implements WorkoutHistoryRepository {
  _Repository(this.read);

  final Future<WorkoutHistoryDetail?> Function(WorkoutSessionId) read;

  @override
  Future<WorkoutHistoryDetail?> getCompletedHistoryDetail(
          WorkoutSessionId sessionId) =>
      read(sessionId);

  @override
  Future<WorkoutHistoryPageResult> listCompletedHistory({
    WorkoutHistoryCursor? after,
  }) async =>
      const WorkoutHistoryPageResult(entries: [], hasMore: false);
}

WorkoutHistoryDetail _detail({
  String? description,
  String? gym,
  double? volumeKg = 400,
}) =>
    WorkoutHistoryDetail(
      summary: WorkoutHistoryEntry(
        sessionId: _sessionId,
        completedAtUtc: _started.add(const Duration(minutes: 44)),
        displayAt: DateTime(2026, 11, 11, 21, 44),
        title: 'Shoulders & Triceps',
        duration: const Duration(minutes: 44),
        volumeKg: volumeKg,
        description: description,
        gymName: gym,
        exercises: const [],
      ),
      exercises: [
        WorkoutHistoryDetailExercise(
          ref: CatalogExerciseRef('ex_spinning'),
          name: 'Spinning',
          exerciseType: ExerciseType.duration,
          sets: [
            PerformedSet(
              id: '33333333-3333-4333-a333-333333333333',
              exerciseRef: CatalogExerciseRef('ex_spinning'),
              sessionExerciseIndex: 0,
              setIndex: 0,
              durationSeconds: 429,
              completedAtUtc: _started,
            ),
          ],
        ),
        WorkoutHistoryDetailExercise(
          ref: CatalogExerciseRef('ex_elliptical'),
          name: 'Elliptical Trainer',
          exerciseType: ExerciseType.distanceDuration,
          sets: [
            PerformedSet(
              id: '44444444-4444-4444-a444-444444444444',
              exerciseRef: CatalogExerciseRef('ex_elliptical'),
              sessionExerciseIndex: 1,
              setIndex: 0,
              distanceMeters: 0,
              durationSeconds: 22,
              completedAtUtc: _started,
            ),
          ],
        ),
        WorkoutHistoryDetailExercise(
          ref: CatalogExerciseRef('ex_shoulder_press'),
          name: 'Shoulder Press',
          exerciseType: ExerciseType.weightReps,
          sets: [
            for (var index = 0; index < 3; index++)
              PerformedSet(
                id: '55555555-5555-4555-a555-55555555555$index',
                exerciseRef: CatalogExerciseRef('ex_shoulder_press'),
                sessionExerciseIndex: 2,
                setIndex: index,
                reps: 10,
                loadKg: 10,
                completedAtUtc: _started,
              ),
          ],
        ),
      ],
    );

Future<void> _pump(
  WidgetTester tester,
  WorkoutHistoryRepository? repository, {
  TioThemeMode theme = TioThemeMode.light,
  WorkoutSessionId? sessionId,
  double textScale = 1,
  Future<bool?> Function(WorkoutSessionId)? onEdit,
}) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: TioThemeConfig(mode: theme),
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          home: WorkoutHistoryDetailPage(
            sessionId: sessionId ?? _sessionId,
            repository: repository,
            catalogRepository: _Catalog(),
            onEditSession: onEdit,
          ),
        ),
      ),
    );

void main() {
  testWidgets('saved summary and actual exercise measurements are shown',
      (tester) async {
    await _pump(
        tester,
        _Repository((_) async => _detail(
              description: 'Good session',
              gym: 'Main Gym',
            )));
    await tester.pumpAndSettle();
    expect(find.text('Shoulders & Triceps'), findsOneWidget);
    expect(find.text('Good session'), findsOneWidget);
    expect(find.text('Main Gym'), findsOneWidget);
    expect(find.text('44min'), findsOneWidget);
    expect(find.text('400 kg'), findsOneWidget);
    expect(find.text('Sets'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.textContaining('November 11, 2026'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Edit Workout'), findsOneWidget);
    expect(
        tester
            .widget<TextButton>(find.byKey(
              const ValueKey('workout-history-detail-edit'),
            ))
            .onPressed,
        isNull);
    expect(find.text('Spinning'), findsOneWidget);
    expect(find.text('7min 9s'), findsOneWidget);
    await tester.ensureVisible(find.text('Elliptical Trainer'));
    expect(find.text('0 km · 22s'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('WEIGHT & REPS'), 150,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('WEIGHT & REPS'), findsOneWidget);
    expect(find.text('10 kg × 10'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('absent optional description and gym leave no reserved gap',
      (tester) async {
    await _pump(tester, _Repository((_) async => _detail(volumeKg: null)));
    await tester.pumpAndSettle();
    final gapWithoutDescription = tester.getTopLeft(find.text('Time')).dy -
        tester.getBottomLeft(find.text('Shoulders & Triceps')).dy;
    expect(find.text('Good session'), findsNothing);
    expect(find.text('Main Gym'), findsNothing);
    expect(find.text('Volume'), findsNothing);
    await _pump(
        tester,
        _Repository((_) async => _detail(
              description: 'Good session',
              gym: 'Main Gym',
            )));
    await tester.pumpAndSettle();
    final gapWithDescription = tester.getTopLeft(find.text('Time')).dy -
        tester.getBottomLeft(find.text('Shoulders & Triceps')).dy;
    expect(gapWithoutDescription, lessThan(gapWithDescription));
  });

  testWidgets('set number retains its saved slot after a skipped set',
      (tester) async {
    final detail = _detail();
    detail.exercises.first.sets[0] = PerformedSet(
      id: '33333333-3333-4333-a333-333333333333',
      exerciseRef: CatalogExerciseRef('ex_spinning'),
      sessionExerciseIndex: 0,
      setIndex: 2,
      durationSeconds: 429,
      completedAtUtc: _started,
    );
    await _pump(tester, _Repository((_) async => detail));
    await tester.pumpAndSettle();
    expect(find.text('7min 9s'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('loading, retry, not found and old account result isolation',
      (tester) async {
    final oldPending = Completer<WorkoutHistoryDetail?>();
    await _pump(tester, _Repository((_) => oldPending.future));
    expect(find.byKey(const ValueKey('workout-history-detail-loading')),
        findsOneWidget);
    await _pump(tester, _Repository((_) async => null));
    oldPending.complete(_detail(gym: 'Former account gym'));
    await tester.pumpAndSettle();
    expect(find.text('Completed workout not found.'), findsOneWidget);
    expect(find.text('Former account gym'), findsNothing);

    var attempts = 0;
    final retryRepository = _Repository((_) async {
      attempts++;
      if (attempts == 1) throw StateError('offline');
      return _detail();
    });
    await _pump(tester, retryRepository);
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not load'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Shoulders & Triceps'), findsOneWidget);
    expect(attempts, 2);
  });

  testWidgets('compact large text and dark themes keep detail readable',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final theme in [TioThemeMode.dark, TioThemeMode.tioDark]) {
      await _pump(tester, _Repository((_) async => _detail()),
          theme: theme, textScale: 1.6);
      await tester.pumpAndSettle();
      expect(find.text('Shoulders & Triceps'), findsOneWidget);
      expect(find.text('400 kg'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Edit action reaches the right edge and reloads after Update',
      (tester) async {
    var reads = 0;
    WorkoutSessionId? selected;
    await _pump(tester, _Repository((_) async {
      reads++;
      return _detail();
    }), onEdit: (id) async {
      selected = id;
      return true;
    });
    await tester.pumpAndSettle();
    final action = find.byKey(const ValueKey('workout-history-detail-edit'));
    final right = tester.getTopRight(action).dx;
    expect(
        right,
        closeTo(
          tester.view.physicalSize.width / tester.view.devicePixelRatio -
              TioSpacing.lg,
          2,
        ));
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(selected, _sessionId);
    expect(reads, 2);
  });
}
