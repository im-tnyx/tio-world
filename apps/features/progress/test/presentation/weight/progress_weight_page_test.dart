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
    expect(find.text('Log Weight'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
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
    await tester.scrollUntilVisible(loadMore, 300);
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
