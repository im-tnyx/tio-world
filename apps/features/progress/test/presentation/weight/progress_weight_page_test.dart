import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_progress/progress.dart';

void main() {
  final now = DateTime.utc(2026, 10, 26, 10);

  Future<void> pumpPage(
    WidgetTester tester,
    BodyRepository repository, {
    WeightUnit unit = WeightUnit.kg,
    String cycle = 'cycle-one',
    VoidCallback? onWeightLogged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: ProgressWeightPage(
            key: ValueKey(cycle),
            repository: repository,
            unit: unit,
            sessionKey: cycle,
            onWeightLogged: onWeightLogged,
            now: () => now,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty Weight shows truthful first-entry help, no active edit',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    expect(find.text('Weight summary'), findsOneWidget);
    expect(find.text('No measurements in this range'), findsOneWidget);
    expect(find.textContaining('No weight measurements yet'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-log-action')), findsOneWidget);
    expect(find.byIcon(Icons.edit), findsNothing);
  });


  testWidgets('Log sheet reuses wheel; Notes icon alone expands text field',
      (tester) async {
    await pumpPage(tester, InMemoryBodySetupRepository());
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsNothing);
    final photo = tester.widget<IconButton>(
      find.byKey(const ValueKey('progress-log-photo-later')),
    );
    expect(photo.onPressed, isNull);
    await tester.tap(find.byKey(const ValueKey('progress-log-note-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsOneWidget);
  });

  testWidgets('A3 optional note persists on Save and History refreshes',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-note-toggle')));
    await tester.pumpAndSettle();
    final field = find.descendant(
      of: find.byKey(const ValueKey('progress-log-note-field')),
      matching: find.byType(EditableText),
    );
    await tester.enterText(field, 'Morning check-in');
    await tester.ensureVisible(find.byKey(const ValueKey('progress-log-save')));
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.note, 'Morning check-in');
    expect(repository.weightEntries.single.source, BodyWeightSources.manual);
    expect(find.text('Morning check-in'), findsOneWidget);
  });


  testWidgets('collapsing notes field preserves its typed text on Save',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-note-toggle')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('progress-log-note-field')),
        matching: find.byType(EditableText),
      ),
      '  After the run  ',
    );
    await tester.tap(find.byKey(const ValueKey('progress-log-note-toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('progress-log-note-field')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries.single.note, 'After the run');
    expect(find.text('After the run'), findsOneWidget);
  });

  testWidgets('300 emoji graphemes save as 300 visible characters',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-note-toggle')));
    await tester.pumpAndSettle();
    final message = List.filled(300, '😀').join();
    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('progress-log-note-field')),
        matching: find.byType(EditableText),
      ),
      message,
    );
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.note, message);
  });

  testWidgets('ambiguous failed submission retries same ID exactly once',
      (tester) async {
    final repository = _AmbiguousSaveWeightRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(find.textContaining('Save not confirmed'), findsOneWidget);
    expect(find.textContaining('Details are locked'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.attempts, 2);
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsNothing);
  });


  testWidgets('Back and barrier cannot close while weight save is in flight',
      (tester) async {
    final repository = _DelayedSaveRepository();
    await pumpPage(tester, repository);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pump();
    // A pending save has a stable operation ID and must retain its modal.
    await tester.tapAt(const Offset(1, 1));
    await tester.pump();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byKey(const ValueKey('progress-log-save')), findsOneWidget);
    repository.release.complete();
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(find.byKey(const ValueKey('progress-log-wheel')), findsNothing);
  });

  testWidgets('confirmed save notifies owning app composition exactly once',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    var invalidations = 0;
    await pumpPage(
      tester,
      repository,
      onWeightLogged: () => invalidations++,
    );
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(invalidations, 1);
    expect(repository.weightEntries, hasLength(1));
  });

  testWidgets('lb wheel displays 154.3 then saves matching canonical 70 kg',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    await tester.tap(find.byKey(const ValueKey('progress-weight-log-action')));
    await tester.pumpAndSettle();
    final wheel = tester.widget<TioWeightWheel>(
      find.byKey(const ValueKey('progress-log-wheel')),
    );
    expect(wheel.unit, WeightUnit.lb);
    expect(wheel.showUnitSwitcher, isFalse);
    final drums = find.descendant(
      of: find.byKey(const ValueKey('progress-log-wheel')),
      matching: find.byType(ListWheelScrollView),
    );
    expect(drums, findsNWidgets(2));
    final whole = tester.widget<ListWheelScrollView>(drums.at(0)).controller!
        as FixedExtentScrollController;
    final decimal = tester.widget<ListWheelScrollView>(drums.at(1)).controller!
        as FixedExtentScrollController;
    expect(whole.selectedItem, 154 - 66);
    expect(decimal.selectedItem, 3);
    await tester.tap(find.byKey(const ValueKey('progress-log-save')));
    await tester.pumpAndSettle();
    expect(repository.weightEntries, hasLength(1));
    expect(repository.weightEntries.single.weightKg, closeTo(70, 0.001));
  });

  testWidgets('shows measured Current Weight and global pounds preference',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 70,
        measuredAt: now.subtract(const Duration(days: 3)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository, unit: WeightUnit.lb);
    expect(find.text('154.3 lb'), findsWidgets);
    expect(find.text('Not enough history'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsOneWidget);
  });

  testWidgets('a changed session key discards the previous owner screen',
      (tester) async {
    final first = InMemoryBodySetupRepository();
    await first.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 99,
        measuredAt: now.subtract(const Duration(days: 2)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, first, cycle: 'owner-a-cycle-one');
    expect(find.text('99 kg'), findsWidgets);
    final second = InMemoryBodySetupRepository();
    await pumpPage(tester, second, cycle: 'owner-b-cycle-two');
    expect(find.text('99 kg'), findsNothing);
    expect(find.text('No measurements in this range'), findsOneWidget);
  });

  testWidgets('range menu compares two actual records in the selected window',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 66,
        measuredAt: now.subtract(const Duration(days: 61)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 67,
        measuredAt: now.subtract(const Duration(days: 20)),
        source: BodyWeightSources.manual,
      ),
    );
    await pumpPage(tester, repository);
    expect(find.text('Not enough history'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('progress-weight-range')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Last 90 days').last);
    await tester.pumpAndSettle();
    expect(find.text('+1 kg'), findsOneWidget);
  });

  testWidgets('Load more appends History without duplicate pagination',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    for (var day = 0; day < 32; day++) {
      await repository.recordCurrentWeight(
        BodyWeightRecord(
          weightKg: 70 + day / 10,
          measuredAt: now.subtract(Duration(days: day + 1)),
          source: BodyWeightSources.manual,
        ),
      );
    }
    await pumpPage(tester, repository);
    final loadMore = find.byKey(const ValueKey('progress-weight-load-more'));
    // Jump to the bottom, not merely until the widget is built:
    // a lazily rendered button can still have its tap centre off-screen.
    final scroll = tester.state<ScrollableState>(
      find.descendant(
        of: find.byKey(const ValueKey('progress-weight-scroll')),
        matching: find.byType(Scrollable),
      ).first,
    );
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(loadMore);
    await tester.pumpAndSettle();
    expect(loadMore, findsNothing);
  });

  testWidgets('shows active canonical goal as a target reference',
      (tester) async {
    final repository = InMemoryBodySetupRepository();
    await repository.recordCurrentWeight(
      BodyWeightRecord(
        weightKg: 70,
        measuredAt: now.subtract(const Duration(days: 1)),
        source: BodyWeightSources.manual,
      ),
    );
    await repository.setActiveBodyGoal(
      const BodyGoalUpdate(
        goalType: BodyGoalType.loseWeight,
        targetWeightKg: 65,
        weeklyWeightChangeKg: 0.5,
      ),
    );
    await pumpPage(tester, repository);
    expect(find.text('Your target: 65 kg'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
  });


  testWidgets('pull-to-refresh works with empty short History', (tester) async {
    final repo = _CountingProgressHistoryRepository();
    await pumpPage(tester, repo);
    final callsBefore = repo.historyCalls;
    expect(find.text('No measurements in this range'), findsOneWidget);
    final scroll = find.byKey(const ValueKey('progress-weight-scroll'));
    final widget = tester.widget<ListView>(scroll);
    expect(widget.physics, isA<AlwaysScrollableScrollPhysics>());
    await tester.drag(scroll, const Offset(0, 350));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(repo.historyCalls, greaterThan(callsBefore));
    expect(find.textContaining('No weight measurements yet'), findsOneWidget);
  });

  testWidgets('load failure offers retry without exposing stale weights',
      (tester) async {
    await pumpPage(tester, _FailingWeightRepository());
    expect(find.text('Weight could not be loaded.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('progress-weight-chart')), findsNothing);
  });
}

class _FailingWeightRepository extends InMemoryBodySetupRepository {
  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) => Future.error(StateError('private transport failure'));
}

class _CountingProgressHistoryRepository extends InMemoryBodySetupRepository {
  int historyCalls = 0;

  @override
  Future<BodyWeightHistoryPage> getWeightHistory(
    BodyWeightHistoryQuery query,
  ) {
    historyCalls++;
    return super.getWeightHistory(query);
  }
}

class _AmbiguousSaveWeightRepository extends InMemoryBodySetupRepository {
  int attempts = 0;

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    attempts++;
    await super.recordCurrentWeight(record);
    if (attempts == 1) {
      throw StateError('Response lost after write committed');
    }
  }
}

class _DelayedSaveRepository extends InMemoryBodySetupRepository {
  final Completer<void> release = Completer<void>();

  @override
  Future<void> recordCurrentWeight(BodyWeightRecord record) async {
    await release.future;
    return super.recordCurrentWeight(record);
  }
}
