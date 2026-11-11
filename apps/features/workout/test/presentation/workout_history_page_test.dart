import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

const _id = '22222222-2222-4222-a222-222222222222';

class _FakeCatalogRepository implements ExerciseCatalogRepository {
  @override
  Future<ExerciseCatalog> load() async => ExerciseCatalog(const []);
}

class _FakeHistoryRepository implements WorkoutHistoryRepository {
  _FakeHistoryRepository(this.read);

  final Future<WorkoutHistoryPageResult> Function(WorkoutHistoryCursor?) read;

  @override
  Future<WorkoutHistoryPageResult> listCompletedHistory({
    WorkoutHistoryCursor? after,
  }) =>
      read(after);
}

WorkoutHistoryEntry _entry({
  String id = _id,
  String? description,
  String? gym,
  int exerciseCount = 1,
}) =>
    WorkoutHistoryEntry(
      sessionId: WorkoutSessionId(id),
      completedAtUtc: DateTime.utc(2026, 11, 11, 9),
      displayAt: DateTime.utc(2026, 11, 11, 14, 30),
      title: 'Shoulders',
      duration: const Duration(minutes: 53),
      description: description,
      gymName: gym,
      exercises: [
        for (var i = 0; i < exerciseCount; i++)
          WorkoutHistoryExercise(
            ref: CatalogExerciseRef('ex_bench_press'),
            name: 'Bench Press $i',
            setCount: i + 1,
          ),
      ],
    );

Future<void> _pumpPage(
  WidgetTester tester,
  WorkoutHistoryRepository repository, {
  TioThemeMode theme = TioThemeMode.light,
}) =>
    tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => TioTheme(
            config: TioThemeConfig(mode: theme),
            child: child ?? const SizedBox.shrink(),
          ),
          home: WorkoutHistoryPage(
            repository: repository,
            catalogRepository: _FakeCatalogRepository(),
          ),
        ),
      ),
    );

void main() {
  testWidgets('card shows saved time and duration without blank optional gaps',
      (tester) async {
    Future<void> pump(WorkoutHistoryEntry entry) => tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => TioTheme(
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: WorkoutHistoryCard(entry: entry, mediaFor: (_) => null),
              ),
            ),
          ),
        );
    await pump(_entry());
    expect(find.text('Shoulders'), findsOneWidget);
    expect(find.textContaining('Nov 11'), findsOneWidget);
    expect(find.textContaining('2:30'), findsOneWidget);
    expect(find.text('53min'), findsOneWidget);
    expect(find.text('1 set Bench Press 0'), findsOneWidget);
    final absentGap = tester.getTopLeft(find.text('Time')).dy -
        tester.getBottomLeft(find.text('Shoulders')).dy;

    await pump(_entry(description: 'Great effort', gym: 'Main Gym'));
    expect(find.text('Great effort'), findsOneWidget);
    expect(find.text('Main Gym'), findsOneWidget);
    final presentGap = tester.getTopLeft(find.text('Time')).dy -
        tester.getBottomLeft(find.text('Shoulders')).dy;
    expect(absentGap, lessThan(presentGap));
  });

  testWidgets('History loading, error, retry and empty state', (tester) async {
    final pending = Completer<WorkoutHistoryPageResult>();
    var calls = 0;
    final repository = _FakeHistoryRepository((_) {
      calls++;
      if (calls == 1) return pending.future;
      return Future.value(const WorkoutHistoryPageResult(
        entries: [],
        hasMore: false,
      ));
    });
    await _pumpPage(tester, repository);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('Could not load workout history'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('No completed workouts yet.'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('account switch discards former owner async result',
      (tester) async {
    final oldPending = Completer<WorkoutHistoryPageResult>();
    final former = _FakeHistoryRepository((_) => oldPending.future);
    final current =
        _FakeHistoryRepository((_) async => WorkoutHistoryPageResult(
              entries: [_entry(id: '33333333-3333-4333-a333-333333333333')],
              hasMore: false,
            ));
    await _pumpPage(tester, former);
    await _pumpPage(tester, current);
    await tester.pumpAndSettle();
    oldPending.complete(WorkoutHistoryPageResult(
      entries: [_entry()],
      hasMore: false,
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('history-card-$_id')), findsNothing);
    expect(
        find.byKey(const ValueKey(
            'history-card-33333333-3333-4333-a333-333333333333')),
        findsOneWidget);
  });

  testWidgets('load more deduplicates rows and shows truthful preview count',
      (tester) async {
    var calls = 0;
    final repository = _FakeHistoryRepository((cursor) async {
      calls++;
      if (cursor == null) {
        return WorkoutHistoryPageResult(
          entries: [_entry(exerciseCount: 8)],
          hasMore: true,
          nextCursor: WorkoutHistoryCursor(
              DateTime.utc(2026, 11, 11, 9), WorkoutSessionId(_id)),
        );
      }
      return WorkoutHistoryPageResult(
        entries: [
          _entry(),
          _entry(id: '33333333-3333-4333-a333-333333333333'),
        ],
        hasMore: false,
      );
    });
    await _pumpPage(tester, repository);
    await tester.pumpAndSettle();
    expect(find.text('3 more exercises'), findsOneWidget);
    await tester.ensureVisible(find.text('Load more'));
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(WorkoutHistoryCard), findsNWidgets(2));
  });

  testWidgets('compact width and large text keep card readable in dark modes',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final mode in [TioThemeMode.dark, TioThemeMode.tioDark]) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.6),
            ),
            child: TioTheme(
              config: TioThemeConfig(mode: mode),
              child: child ?? const SizedBox.shrink(),
            ),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: WorkoutHistoryCard(
                entry: _entry(exerciseCount: 6),
                mediaFor: (_) => null,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Shoulders'), findsOneWidget);
    }
  });
}
