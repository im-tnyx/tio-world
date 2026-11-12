import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final _id = WorkoutSessionId('22222222-2222-4222-a222-222222222222');
final _completed = DateTime.utc(2026, 11, 11, 21);

WorkoutHistoryDetail _detail() {
  final raw = <String, dynamic>{
    'schema_version': 2,
    'origin': 'ad_hoc',
    'captured_at_utc': '2026-11-11T20:00:00Z',
    'exercises': [
      {
        'exercise_ref': 'ex_bench_press',
        'display_name': 'Bench Press',
        'exercise_type': 'weight_reps',
        'occurrence_index': 0,
        'prescribed_sets': [
          {'set_type': 'normal'}
        ],
      }
    ],
  };
  final set = PerformedSet(
    id: '33333333-3333-4333-a333-333333333333',
    exerciseRef: CatalogExerciseRef('ex_bench_press'),
    sessionExerciseIndex: 0,
    setIndex: 0,
    reps: 10,
    loadKg: 40,
    completedAtUtc: DateTime.utc(2026, 11, 11, 20, 40),
  );
  return WorkoutHistoryDetail(
    summary: WorkoutHistoryEntry(
      sessionId: _id,
      completedAtUtc: _completed,
      displayAt: DateTime(2026, 11, 12, 2, 30),
      title: 'Shoulders & Triceps',
      duration: const Duration(minutes: 44),
      volumeKg: 400,
      exercises: const [],
      gymName: 'Main Gym',
    ),
    exercises: [
      WorkoutHistoryDetailExercise(
        ref: CatalogExerciseRef('ex_bench_press'),
        name: 'Bench Press',
        exerciseType: ExerciseType.weightReps,
        sets: [set],
      ),
    ],
    revision: 2,
    rawSnapshot: raw,
    snapshot: WorkoutSessionSnapshotDto.fromJson(raw),
    allPerformedSets: [set],
    workoutAtUtc: DateTime.utc(2026, 11, 11, 20, 30),
    utcOffsetMinutes: 330,
    activityType: 'Weight Training',
  );
}

class _History implements WorkoutHistoryRepository {
  _History(this.read);
  final Future<WorkoutHistoryDetail?> Function() read;
  @override
  Future<WorkoutHistoryDetail?> getCompletedHistoryDetail(
          WorkoutSessionId sessionId) =>
      read();
  @override
  Future<WorkoutHistoryPageResult> listCompletedHistory({
    WorkoutHistoryCursor? after,
  }) async =>
      const WorkoutHistoryPageResult(entries: [], hasMore: false);
}

class _Editor implements WorkoutHistoryEditRepository {
  WorkoutHistoryEditRequest? submitted;
  @override
  Future<WorkoutHistoryDetail> updateCompletedWorkout(
      WorkoutHistoryEditRequest request) async {
    submitted = request;
    return _detail();
  }
}

class _Catalog implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog(const []);
}

Future<void> _pump(WidgetTester tester, _History history, _Editor editor,
    {TioThemeMode mode = TioThemeMode.dark,
    double scale = 1,
    bool settle = true}) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(
      builder: (context, child) => TioTheme(
        config: TioThemeConfig(mode: mode),
        child: MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child ?? const SizedBox.shrink(),
        ),
      ),
      home: Builder(
          builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () =>
                      Navigator.of(context).push(MaterialPageRoute<bool>(
                    builder: (_) => EditWorkoutPage(
                      sessionId: _id,
                      historyRepository: history,
                      editRepository: editor,
                      catalogRepository: _Catalog(),
                    ),
                  )),
                  child: const Text('Open editor'),
                ),
              )),
    ),
  ));
  await tester.tap(find.text('Open editor'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  testWidgets('Edit combines Save metadata and actual Log set then updates',
      (tester) async {
    final editor = _Editor();
    await _pump(tester, _History(() async => _detail()), editor);
    expect(find.text('Edit Workout'), findsOneWidget);
    expect(find.byTooltip('Close Edit Workout'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
    expect(find.text('400 kg'), findsOneWidget);
    await tester.ensureVisible(find.text('Bench Press'));
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-workout-add-exercise')),
        findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const ValueKey('edit-workout-update-button')));
    await tester.tap(find.byKey(const ValueKey('edit-workout-update-button')));
    await tester.pumpAndSettle();
    expect(editor.submitted?.source.summary.sessionId, _id);
    expect(editor.submitted?.exercises.single.sets.single.reps, 10);
    expect(find.text('Open editor'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline retry and stale account result do not show old data',
      (tester) async {
    final old = Completer<WorkoutHistoryDetail?>();
    final history = _History(() => old.future);
    final editor = _Editor();
    await _pump(tester, history, editor, settle: false);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Route disposal must prevent the old response from painting after Cancel.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    old.complete(_detail());
    await tester.pumpAndSettle();
    expect(find.text('Shoulders & Triceps'), findsNothing);
  });

  testWidgets('Edit set values align with Log Workout header columns',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, _History(() async => _detail()), _Editor());
    await tester.ensureVisible(find.text('Bench Press'));

    const setId = '33333333-3333-4333-a333-333333333333';
    final previousValue =
        find.byKey(const ValueKey('routine-set-previous-$setId'));
    final rpeValue = find.byKey(const ValueKey('edit-workout-rpe-$setId'));
    final toggle = find.byKey(const ValueKey('edit-workout-set-toggle-$setId'));
    expect(previousValue, findsOneWidget);
    expect(find.text('RPE'), findsOneWidget);
    expect(rpeValue, findsOneWidget);
    expect(toggle, findsOneWidget);
    expect(tester.widget<Text>(previousValue).data, '–');
    expect(
        (tester.getCenter(find.text('PREVIOUS')).dx -
                tester.getCenter(previousValue).dx)
            .abs(),
        lessThan(1));
    // The weight icon sits beside KG, so compare the header cell center.
    final kgHeaderCell = find
        .ancestor(of: find.text('KG'), matching: find.byType(LayoutBuilder))
        .first;
    expect(
        (tester.getCenter(kgHeaderCell).dx -
                tester.getCenter(find.text('40')).dx)
            .abs(),
        lessThan(1));
    expect(
        (tester.getCenter(find.text('REPS')).dx -
                tester.getCenter(find.text('10')).dx)
            .abs(),
        lessThan(1));
    expect(
        (tester.getCenter(find.text('RPE')).dx - tester.getCenter(rpeValue).dx)
            .abs(),
        lessThan(1));
    expect(
        (tester.getCenter(find.text('✓')).dx - tester.getCenter(toggle).dx)
            .abs(),
        lessThan(1));

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final loadField = find.byKey(const ValueKey('routine-set-weight-$setId'));
    final repsField = find.byKey(const ValueKey('routine-set-reps-$setId'));
    expect(loadField, findsOneWidget);
    expect(repsField, findsOneWidget);
    expect(
        (tester.getCenter(kgHeaderCell).dx - tester.getCenter(loadField).dx)
            .abs(),
        lessThan(1));
    expect(
        (tester.getCenter(find.text('REPS')).dx -
                tester.getCenter(repsField).dx)
            .abs(),
        lessThan(1));
    await tester.enterText(repsField, '12');
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Edit set RPE uses Log sheet and reaches Update request',
      (tester) async {
    final editor = _Editor();
    await _pump(tester, _History(() async => _detail()), editor);
    const setId = '33333333-3333-4333-a333-333333333333';
    final rpe = find.byKey(const ValueKey('edit-workout-rpe-$setId'));
    await tester.ensureVisible(rpe);
    await tester.tap(rpe);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('rpe-option-7.5')));
    await tester.tap(find.byKey(const ValueKey('rpe-sheet-done-button')));
    await tester.pumpAndSettle();
    expect(find.text('7.5'), findsOneWidget);
    await tester.ensureVisible(
        find.byKey(const ValueKey('edit-workout-update-button')));
    await tester.tap(find.byKey(const ValueKey('edit-workout-update-button')));
    await tester.pumpAndSettle();
    expect(editor.submitted?.exercises.single.sets.single.rpe, 7.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact OLED layout retains Update and exercise controls',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(tester, _History(() async => _detail()), _Editor(),
        mode: TioThemeMode.tioDark, scale: 1.6);
    expect(find.text('Edit Workout'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    await tester.ensureVisible(find.text('Bench Press'));
    expect(find.text('PREVIOUS'), findsOneWidget);
    expect(find.text('RPE'), findsNothing);
    final greenRow = find.byKey(const ValueKey(
        'edit-workout-row-33333333-3333-4333-a333-333333333333'));
    expect(tester.getTopLeft(greenRow).dx, 0);
    expect(tester.getTopRight(greenRow).dx, 320);
    expect(tester.takeException(), isNull);
  });
}
